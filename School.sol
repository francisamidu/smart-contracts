// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract School {
    string public name;
    struct Student {
        string studentName;
        address studentId;
    }

    struct Lecture {
        string name;
        address lecturerId;
    }

    event StudentAdded(address studentId,string studentName);

    mapping (address=>Student) public students;
    mapping (address=>Lecture) public lecturers;

    constructor (string memory schoolName) public {
        name = schoolName;
    }

    function setSchoolName(string memory schoolName) public returns(string memory) {
        name = schoolName;
        return schoolName;
    }

    function setStudent(string memory studentName,address studentId) public returns(bool){
        students[studentId] = Student(studentName,studentId);
        emit StudentAdded(studentId,studentName);
        return true;
    }

    function getStudent(address studentId) public view returns(Student memory){
        return students[studentId];
    }
    function setLecture(string memory lecturerName,address lecturerId) public returns(bool){       
        lecturers[lecturerId] = Lecture(lecturerName,lecturerId);
        return true;
    }

    function getLecture(address lecturerId) public view returns(Lecture memory) {
        return lecturers[lecturerId];
    }


}